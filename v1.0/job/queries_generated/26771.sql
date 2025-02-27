WITH RankedMovies AS (
    SELECT 
        a.id AS aka_id,
        a.name AS aka_name,
        t.id AS title_id,
        t.title AS movie_title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rn
    FROM aka_title a
    JOIN title t ON a.movie_id = t.id
    WHERE t.production_year IS NOT NULL
),
TopMovies AS (
    SELECT *
    FROM RankedMovies
    WHERE rn <= 5
),
CastDetails AS (
    SELECT 
        c.movie_id,
        c.person_id,
        p.imdb_index AS person_imdb_index,
        p.gender AS person_gender,
        r.role AS role_name
    FROM cast_info c 
    JOIN ak_name p ON c.person_id = p.person_id
    JOIN role_type r ON c.role_id = r.id
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        co.name AS company_name,
        ct.kind AS company_type
    FROM movie_companies mc
    JOIN company_name co ON mc.company_id = co.id
    JOIN company_type ct ON mc.company_type_id = ct.id
),
MovieInfo AS (
    SELECT 
        m.movie_id,
        STRING_AGG(CONCAT('Info: ', mi.info, ' Notes: ', mi.note), '; ') AS aggregated_info
    FROM movie_info m
    JOIN movie_info_idx mi ON m.movie_id = mi.movie_id
    GROUP BY m.movie_id
)
SELECT 
    tm.aka_name,
    tm.movie_title,
    tm.production_year,
    cd.person_imdb_index,
    cd.person_gender,
    cd.role_name,
    comp.company_name,
    comp.company_type,
    mi.aggregated_info
FROM TopMovies tm
LEFT JOIN CastDetails cd ON tm.title_id = cd.movie_id
LEFT JOIN CompanyDetails comp ON tm.title_id = comp.movie_id
LEFT JOIN MovieInfo mi ON tm.title_id = mi.movie_id
ORDER BY tm.production_year DESC, tm.movie_title, cd.role_name;
