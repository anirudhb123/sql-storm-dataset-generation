WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        ARRAY_AGG(DISTINCT cn.name) AS company_names,
        ROW_NUMBER() OVER (ORDER BY m.production_year DESC) AS rank
    FROM 
        title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    WHERE 
        m.production_year >= 2010
    GROUP BY 
        m.id
),
PopularActors AS (
    SELECT 
        p.name,
        COUNT(ci.movie_id) AS movies_count
    FROM 
        aka_name p
    JOIN 
        cast_info ci ON p.person_id = ci.person_id
    JOIN 
        title m ON ci.movie_id = m.id
    WHERE 
        m.production_year >= 2010
    GROUP BY 
        p.name
    ORDER BY 
        movies_count DESC
    LIMIT 10
),
FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.keywords,
        rm.company_names
    FROM 
        RankedMovies rm
    JOIN 
        PopularActors pa ON pa.movies_count > 5
    ON 
        EXISTS (
            SELECT 
                1 
            FROM 
                cast_info ci 
            WHERE 
                ci.movie_id = rm.movie_id 
                AND ci.person_id IN (SELECT person_id FROM aka_name WHERE name = pa.name)
        )
)
SELECT 
    fm.title,
    fm.production_year,
    fm.keywords,
    fm.company_names
FROM 
    FilteredMovies fm
ORDER BY 
    fm.production_year DESC;
