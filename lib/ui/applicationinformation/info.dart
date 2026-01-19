import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/information_block/info_bloc.dart';
import '../../blocs/information_block/info_contract.dart';
import '../../core/base_state.dart';
import '../../core/screen_state.dart';
import '../common/app_gradient_container.dart';

class Info extends StatefulWidget {
  const Info({super.key});

  @override
  State<Info> createState() => _InfoState();
}

class _InfoState extends BaseState<InfoBloc, Info>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _cityController = TextEditingController();

  bool _loadedOnce = false;

  @override
  void initState() {
    super.initState();

    /// 🔥 LOAD DATA ONLY ON FIRST VISIT
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_loadedOnce) {
        _loadedOnce = true;
        bloc.add(InitEvent());
        bloc.add(ProductDataEvent());
      }
    });
  }

  @override
  void dispose() {
    _cityController.dispose();

    /// 🔥 Optional cleanup (streams / timers / tokens)
    // bloc.add(CancelInfoEvent()); // if you add cancel support
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Weather & Products Info')),
      body: AppBgContainer(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildCitySearch(),
              const SizedBox(height: 20),
              _buildWeatherSection(),
              const SizedBox(height: 20),
              Expanded(child: _buildProductsSection()),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // WEATHER SEARCH
  // ------------------------------------------------------------

  Widget _buildCitySearch() {
    return TextField(
      controller: _cityController,
      decoration: InputDecoration(
        hintText: 'Enter city name',
        suffixIcon: IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            if (_cityController.text.isNotEmpty) {
              bloc.add(GetWeatherEvent(_cityController.text));
            }
          },
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // WEATHER RESULT
  // ------------------------------------------------------------

  Widget _buildWeatherSection() {
    return BlocBuilder<InfoBloc, InfoData>(
      bloc: bloc,
      buildWhen: (p, c) =>
      p.state != c.state ||
          p.description != c.description,
      builder: (context, state) {
        if (state.state == ScreenState.loading &&
            state.description == null) {
          return const _WeatherSkeleton();
        }

        if (state.state == ScreenState.error) {
          return Text(
            state.errorMessage ?? 'Error loading weather',
            style: const TextStyle(color: Colors.red),
          );
        }

        if (state.description != null) {
          return Column(
            children: [
              Text(state.cityName ?? ''),
              const SizedBox(height: 8),
              Text(
                '${state.temperature?.toStringAsFixed(1)}°C',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(state.description!),
            ],
          );
        }

        return const Text('Search a city to get weather');
      },
    );
  }

  // ------------------------------------------------------------
  // PRODUCTS LIST
  // ------------------------------------------------------------

  Widget _buildProductsSection() {
    return BlocBuilder<InfoBloc, InfoData>(
      bloc: bloc,
      buildWhen: (p, c) => p.productsdata != c.productsdata ||
          p.state != c.state,
      builder: (context, state) {
        if (state.state == ScreenState.loading &&
            (state.productsdata == null ||
                state.productsdata!.isEmpty)) {
          return const _ProductsSkeleton();
        }

        if (state.state == ScreenState.error &&
            (state.productsdata == null ||
                state.productsdata!.isEmpty)) {
          return Text(
            state.errorMessage ?? 'Error loading products',
            style: const TextStyle(color: Colors.red),
          );
        }

        if (state.productsdata != null &&
            state.productsdata!.isNotEmpty) {
          return ListView.builder(
            itemCount: state.productsdata!.length,
            itemBuilder: (context, index) {
              final product = state.productsdata![index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  leading: Image.network(
                    product['thumbnail'],
                    width: 60,
                    fit: BoxFit.cover,
                  ),
                  title: Text(product['title']),
                  subtitle: Text(product['description']),
                  trailing: Text('\$${product['price']}'),
                ),
              );
            },
          );
        }

        return const Text('No products available');
      },
    );
  }
}

// ===================================================================
// 🦴 SKELETONS (LIGHTWEIGHT & FAST)
// ===================================================================

class _WeatherSkeleton extends StatelessWidget {
  const _WeatherSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(height: 18, width: 120, color: Colors.grey.shade300),
        const SizedBox(height: 8),
        Container(height: 24, width: 80, color: Colors.grey.shade300),
      ],
    );
  }
}

class _ProductsSkeleton extends StatelessWidget {
  const _ProductsSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 6,
      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        height: 70,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
