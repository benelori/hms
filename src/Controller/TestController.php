<?php

declare(strict_types=1);

namespace App\Controller;

use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\Routing\Annotation\Route;

class TestController
{
    #[Route(path: '/test', name: 'test', methods: ['GET'])]
    public function test(): JsonResponse
    {
        return new JsonResponse(['test']);
    }
}
