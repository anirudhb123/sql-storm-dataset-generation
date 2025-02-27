WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year, 
        t.kind_id, 
        RANK() OVER (PARTITION BY t.kind_id ORDER BY t.production_year DESC) AS rank
    FROM 
        aka_title AS t
    WHERE 
        t.production_year IS NOT NULL
),
FilteredMovies AS (
    SELECT 
        rm.movie_id, 
        rm.title, 
        rm.production_year,
        k.keyword,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        RankedMovies AS rm
    LEFT JOIN 
        movie_keyword AS mk ON rm.movie_id = mk.movie_id
    LEFT JOIN 
        keyword AS k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies AS mc ON rm.movie_id = mc.movie_id
    WHERE 
        rm.rank <= 5
        AND (k.keyword IS NOT NULL OR rm.production_year < 2000)
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year, k.keyword
),
CastDetails AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS artist_count,
        STRING_AGG(DISTINCT n.name, ', ') AS artist_names
    FROM 
        cast_info AS ci
    INNER JOIN 
        aka_name AS n ON ci.person_id = n.person_id
    WHERE 
        ci.nr_order < 3 
    GROUP BY 
        ci.movie_id
),
MovieSummary AS (
    SELECT 
        fm.movie_id,
        fm.title,
        fm.production_year,
        COALESCE(cd.artist_count, 0) AS artist_count,
        cd.artist_names,
        fm.company_count
    FROM 
        FilteredMovies AS fm
    LEFT JOIN 
        CastDetails AS cd ON fm.movie_id = cd.movie_id
)
SELECT 
    ms.movie_id,
    ms.title,
    ms.production_year,
    ms.artist_count,
    ms.artist_names,
    ms.company_count,
    CASE 
        WHEN ms.company_count > 10 THEN 'Major Production'
        WHEN ms.company_count BETWEEN 5 AND 10 THEN 'Moderate Production'
        ELSE 'Indie Production'
    END AS production_scale,
    CASE 
        WHEN ms.artist_count IS NULL OR ms.artist_count = 0 THEN 'No Cast Available'
        ELSE 'Cast Info Available'
    END AS availability
FROM 
    MovieSummary AS ms
WHERE 
    ms.production_year IS NOT NULL
ORDER BY 
    ms.production_year DESC, 
    ms.artist_count DESC
LIMIT 10;