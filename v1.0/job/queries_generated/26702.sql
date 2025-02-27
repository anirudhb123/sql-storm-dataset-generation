WITH RankedMovies AS (
    SELECT
        a.id AS movie_id,
        a.title,
        a.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
        ROW_NUMBER() OVER (ORDER BY a.production_year DESC) AS rank
    FROM aka_title a
    LEFT JOIN cast_info ci ON a.id = ci.movie_id
    LEFT JOIN aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN keyword kw ON mk.keyword_id = kw.id
    WHERE a.production_year IS NOT NULL
    GROUP BY a.id, a.title, a.production_year
),
FilteredMovies AS (
    SELECT
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.total_cast,
        rm.cast_names,
        rm.keywords
    FROM RankedMovies rm
    WHERE rm.total_cast > 5
      AND rm.production_year >= 2000
)
SELECT
    fm.title,
    fm.production_year,
    fm.total_cast,
    fm.cast_names,
    fm.keywords,
    ct.kind AS company_type,
    cn.name AS production_company
FROM FilteredMovies fm
LEFT JOIN movie_companies mc ON fm.movie_id = mc.movie_id
LEFT JOIN company_name cn ON mc.company_id = cn.id
LEFT JOIN company_type ct ON mc.company_type_id = ct.id
ORDER BY fm.production_year DESC, fm.total_cast DESC;
