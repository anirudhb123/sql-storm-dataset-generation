WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        a.name AS actor_name,
        ct.kind AS cast_type,
        k.keyword AS movie_keyword,
        GROUP_CONCAT(DISTINCT CONCAT_WS(' - ', ci.nr_order, a.md5sum)) AS actor_info,
        GROUP_CONCAT(DISTINCT mi.info) AS movie_info_details
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        comp_cast_type ct ON ci.person_role_id = ct.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id
    WHERE 
        t.production_year BETWEEN 1990 AND 2023
    GROUP BY 
        t.id, a.name, ct.kind, t.production_year
),
RankedMovies AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY movie_title) AS movie_rank
    FROM 
        MovieDetails
)
SELECT 
    movie_title,
    production_year,
    actor_name,
    cast_type,
    movie_keyword,
    actor_info,
    movie_info_details
FROM 
    RankedMovies
WHERE 
    movie_rank <= 5
ORDER BY 
    production_year DESC, movie_rank;
