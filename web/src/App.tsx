import { BrowserRouter, Navigate, Route, Routes } from 'react-router-dom';
import { AuthProvider, useAuth } from './state/AuthContext';
import { AppStoreProvider } from './state/AppStore';
import { Layout } from './components/Layout';
import SignInPage from './pages/SignInPage';
import SignUpPage from './pages/SignUpPage';
import ForgotPasswordPage from './pages/ForgotPasswordPage';
import ResetPasswordPage from './pages/ResetPasswordPage';
import EmailConfirmationPage from './pages/EmailConfirmationPage';
import DashboardPage from './pages/DashboardPage';
import GoalsPage from './pages/GoalsPage';
import BlockerPage from './pages/BlockerPage';
import WorkoutPage from './pages/WorkoutPage';
import SocialPage from './pages/SocialPage';
import FriendDashboardPage from './pages/FriendDashboardPage';
import ProfilePage from './pages/ProfilePage';

function RootGate() {
  const { ready, signedIn, passwordRecoveryPending } = useAuth();

  if (!ready) {
    return (
      <div className="flex min-h-svh items-center justify-center bg-background">
        <div className="h-8 w-8 animate-spin rounded-full border-4 border-cyan-soft border-t-cyan" />
      </div>
    );
  }

  if (passwordRecoveryPending) {
    return (
      <Routes>
        <Route path="*" element={<ResetPasswordPage />} />
      </Routes>
    );
  }

  if (!signedIn) {
    return (
      <Routes>
        <Route path="/sign-up" element={<SignUpPage />} />
        <Route path="/forgot-password" element={<ForgotPasswordPage />} />
        <Route path="/confirm-email" element={<EmailConfirmationPage />} />
        <Route path="*" element={<SignInPage />} />
      </Routes>
    );
  }

  return (
    <AppStoreProvider>
      <Routes>
        <Route element={<Layout />}>
          <Route index element={<DashboardPage />} />
          <Route path="goals" element={<GoalsPage />} />
          <Route path="blocker" element={<BlockerPage />} />
          <Route path="train" element={<WorkoutPage />} />
          <Route path="social" element={<SocialPage />} />
          <Route path="friend/:friendId" element={<FriendDashboardPage />} />
          <Route path="profile" element={<ProfilePage />} />
        </Route>
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </AppStoreProvider>
  );
}

export default function App() {
  return (
    <BrowserRouter>
      <AuthProvider>
        <RootGate />
      </AuthProvider>
    </BrowserRouter>
  );
}
