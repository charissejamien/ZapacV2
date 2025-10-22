// import 'package:flutter/material.dart';
// import 'package:flutter/scheduler.dart';
// import 'package:idiscount/ui/common/text_helpers.dart';
// import 'package:stacked/stacked.dart';
// import 'package:idiscount/ui/common/ui_helpers.dart';

// import 'startup_viewmodel.dart';

// class StartupView extends StackedView<StartupViewModel> {
//   const StartupView({Key? key}) : super(key: key);

//   @override
//   Widget builder(
//     BuildContext context,
//     StartupViewModel viewModel,
//     Widget? child,
//   ) {
//     return Scaffold(
//       body: Center(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Image(
//               image: const AssetImage('assets/iDiscount_Logo_Full.png'),
//               width: screenWidth(context) * 0.6,
//             ),
//             Text(
//               'iDiscount',
//               style: context.textStyle.label.copyWith(
//                   fontSize: 40,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.amber),
//             ),
//             // Row(
//             //   mainAxisSize: MainAxisSize.min,
//             //   children: [
//             //     Text('Loading ...', style: TextStyle(fontSize: 16)),
//             //     horizontalSpaceSmall,
//             //     SizedBox(
//             //       width: 16,
//             //       height: 16,
//             //       child: CircularProgressIndicator(
//             //         color: Colors.black,
//             //         strokeWidth: 6,
//             //       ),
//             //     ),
//             //   ],
//             // ),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   StartupViewModel viewModelBuilder(BuildContext context) => StartupViewModel();

//   @override
//   void onViewModelReady(StartupViewModel viewModel) => SchedulerBinding.instance
//       .addPostFrameCallback((timeStamp) => viewModel.runStartupLogic());
// }