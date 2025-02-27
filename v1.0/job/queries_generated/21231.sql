WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS num_cast_members,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_within_year
    FROM
        aka_title t
    LEFT JOIN cast_info c ON t.id = c.movie_id
    GROUP BY t.id, t.title, t.production_year
),
FilteredMovies AS (
    SELECT *
    FROM RankedMovies
    WHERE num_cast_members > (SELECT AVG(num_cast_members) FROM RankedMovies)
),
RecentlyNamedActors AS (
    SELECT 
        a.person_id, 
        a.name, 
        COUNT(DISTINCT f.movie_id) AS recent_movies_count
    FROM
        aka_name a
    LEFT JOIN cast_info f ON a.person_id = f.person_id
    LEFT JOIN aka_title t ON f.movie_id = t.id
    WHERE t.production_year > 2020
    GROUP BY a.person_id, a.name
    HAVING COUNT(DISTINCT f.movie_id) > 3
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        m.info AS movie_info,
        ARRAY_AGG(DISTINCT k.keyword) AS associated_keywords
    FROM 
        movie_companies mc
    JOIN company_name c ON mc.company_id = c.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    JOIN movie_info m ON mc.movie_id = m.movie_id
    LEFT JOIN movie_keyword mk ON mc.movie_id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mc.movie_id, c.name, ct.kind, m.info
)
SELECT 
    fm.movie_id,
    fm.title,
    fm.production_year,
    ra.name AS actor_name,
    cd.company_name,
    cd.company_type,
    cd.movie_info,
    cd.associated_keywords,
    CASE 
        WHEN fm.rank_within_year <= 5 THEN 'Top 5'
        ELSE 'Below Top 5'
    END AS rank_category
FROM 
    FilteredMovies fm
LEFT JOIN RecentlyNamedActors ra ON ra.recent_movies_count > 0
LEFT JOIN CompanyDetails cd ON fm.movie_id = cd.movie_id
WHERE 
    cd.company_type IS NOT NULL OR EXISTS (
        SELECT 1 
        FROM company_name c 
        WHERE c.name ILIKE '%film%'
    )
ORDER BY 
    fm.production_year DESC, 
    fm.num_cast_members DESC, 
    ra.name;
