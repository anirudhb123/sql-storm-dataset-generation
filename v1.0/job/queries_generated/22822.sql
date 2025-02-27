WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(c.person_id) AS total_cast_size,
        ARRAY_AGG(DISTINCT ak.name ORDER BY ak.name) AS cast_names,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(c.person_id) DESC) AS annual_rank
    FROM aka_title a
    LEFT JOIN cast_info c ON a.id = c.movie_id
    LEFT JOIN aka_name ak ON c.person_id = ak.person_id
    GROUP BY a.id, a.title, a.production_year
),
PopularActors AS (
    SELECT 
        ak.name,
        COUNT(c.movie_id) AS movie_count,
        MAX(a.production_year) AS last_active_year
    FROM aka_name ak
    JOIN cast_info c ON ak.person_id = c.person_id
    JOIN aka_title a ON c.movie_id = a.id
    GROUP BY ak.name
    HAVING COUNT(c.movie_id) > 5
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies_involved,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY mc.movie_id
)

SELECT 
    rm.title,
    rm.production_year,
    rm.total_cast_size,
    rm.cast_names,
    COALESCE(pa.movie_count, 0) AS number_of_movies_with_lead_actor,
    COALESCE(pa.last_active_year, 'N/A') AS last_active_year,
    cd.companies_involved,
    cd.company_types
FROM RankedMovies rm
LEFT JOIN PopularActors pa ON rm.cast_names[1] = pa.name -- assuming the lead actor is the first in alphabetically sorted cast_names
LEFT JOIN CompanyDetails cd ON rm.id = cd.movie_id
WHERE rm.annual_rank <= 10 
  AND rm.production_year IS NOT NULL 
  AND rm.total_cast_size > 0 
  AND (EXISTS (SELECT 1 FROM movie_info mi WHERE mi.movie_id = rm.id AND mi.info_type_id = 1 AND mi.info IS NOT NULL))
ORDER BY rm.production_year DESC, rm.total_cast_size DESC;
