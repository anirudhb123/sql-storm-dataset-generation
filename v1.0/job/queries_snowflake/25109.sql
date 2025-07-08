
WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        k.keyword AS movie_keyword,
        COUNT(DISTINCT c.person_id) AS cast_count,
        COUNT(DISTINCT m.company_id) AS company_count,
        RANK() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_by_cast
    FROM 
        aka_title a
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    LEFT JOIN 
        movie_companies m ON a.id = m.movie_id
    WHERE 
        a.production_year BETWEEN 2000 AND 2023 
    GROUP BY 
        a.id, a.title, a.production_year, k.keyword
),
FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.movie_keyword,
        rm.cast_count,
        rm.company_count,
        rm.rank_by_cast
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank_by_cast <= 5
)
SELECT 
    f.movie_id,
    f.title,
    f.production_year,
    f.movie_keyword,
    f.cast_count,
    f.company_count,
    COALESCE((SELECT LISTAGG(p.name, ', ' ORDER BY p.name) 
              FROM cast_info ci
              JOIN aka_name p ON ci.person_id = p.person_id 
              WHERE ci.movie_id = f.movie_id), 'No Cast') AS cast_names,
    COALESCE((SELECT LISTAGG(DISTINCT cn.name, ', ' ORDER BY cn.name) 
              FROM movie_companies mc
              JOIN company_name cn ON mc.company_id = cn.id 
              WHERE mc.movie_id = f.movie_id), 'No Companies') AS production_companies
FROM 
    FilteredMovies f
ORDER BY 
    f.cast_count DESC, 
    f.company_count DESC;
