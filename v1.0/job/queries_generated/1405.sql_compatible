
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rn
    FROM title t
    WHERE t.production_year IS NOT NULL
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COALESCE(mc.note, 'N/A') AS note
    FROM movie_companies mc
    JOIN company_name c ON mc.company_id = c.id
    JOIN company_type ct ON mc.company_type_id = ct.id
),
MovieCast AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM cast_info ci
    JOIN aka_name a ON ci.person_id = a.person_id
    GROUP BY ci.movie_id
)
SELECT 
    rm.title AS movie_title,
    rm.production_year,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    COALESCE(ci.company_name, 'Unknown Company') AS company_name,
    COALESCE(ci.company_type, 'Unknown Type') AS company_type,
    COALESCE(mcast.cast_count, 0) AS cast_member_count,
    COALESCE(mcast.cast_names, 'No cast') AS cast_members
FROM RankedMovies rm
LEFT JOIN MovieKeywords mk ON rm.movie_id = mk.movie_id
LEFT JOIN CompanyInfo ci ON rm.movie_id = ci.movie_id
LEFT JOIN MovieCast mcast ON rm.movie_id = mcast.movie_id
WHERE rm.rn <= 5
ORDER BY rm.production_year DESC, rm.title ASC
FETCH FIRST 20 ROWS ONLY;
