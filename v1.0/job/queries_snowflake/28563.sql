
WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        a.kind_id,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS cast_names,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords,
        COUNT(m.id) AS company_count
    FROM aka_title a
    LEFT JOIN cast_info c ON a.id = c.movie_id
    LEFT JOIN aka_name ak ON c.person_id = ak.person_id
    LEFT JOIN movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    LEFT JOIN movie_companies m ON a.id = m.movie_id
    GROUP BY a.id, a.title, a.production_year, a.kind_id
),
FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.kind_id,
        rm.cast_names,
        rm.keywords,
        rm.company_count,
        ROW_NUMBER() OVER (PARTITION BY rm.kind_id ORDER BY rm.production_year DESC) AS rank
    FROM RankedMovies rm
    WHERE rm.production_year >= 2000
)
SELECT
    f.title,
    f.production_year,
    f.cast_names,
    f.keywords,
    ct.kind AS company_type,
    f.company_count
FROM FilteredMovies f
JOIN movie_companies mc ON f.movie_id = mc.movie_id 
JOIN company_type ct ON mc.company_type_id = ct.id
WHERE f.rank <= 10
ORDER BY f.production_year DESC, f.title;
