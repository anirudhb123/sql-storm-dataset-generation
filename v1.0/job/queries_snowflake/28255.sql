
WITH MovieInfo AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS aka_names,
        LISTAGG(DISTINCT c.name, ', ') WITHIN GROUP (ORDER BY c.name) AS company_names,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords,
        COUNT(DISTINCT ca.person_id) AS cast_count
    FROM 
        aka_title t
    LEFT JOIN aka_name ak ON ak.person_id = t.id
    LEFT JOIN movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN company_name c ON c.id = mc.company_id
    LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN keyword k ON k.id = mk.keyword_id
    LEFT JOIN cast_info ca ON ca.movie_id = t.id
    GROUP BY 
        t.id, t.title, t.production_year
),
RankedMovies AS (
    SELECT
        movie_id,
        title,
        production_year,
        aka_names,
        company_names,
        keywords,
        cast_count,
        ROW_NUMBER() OVER (ORDER BY production_year DESC, cast_count DESC) AS rank
    FROM 
        MovieInfo
)
SELECT 
    rm.rank,
    rm.title,
    rm.production_year,
    rm.aka_names,
    rm.company_names,
    rm.keywords,
    rm.cast_count
FROM 
    RankedMovies rm
WHERE 
    rm.rank <= 10
ORDER BY 
    rm.rank;
