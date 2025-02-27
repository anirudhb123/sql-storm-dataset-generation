WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY m.md5sum DESC) AS rank
    FROM title t
    JOIN movie_keyword mk ON t.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    JOIN movie_info mi ON t.id = mi.movie_id
    JOIN movie_info_idx mii ON mi.id = mii.movie_id
    LEFT JOIN movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN company_name cn ON mc.company_id = cn.id
    LEFT JOIN company_type ct ON mc.company_type_id = ct.id
    WHERE k.keyword LIKE '%thriller%' AND mi.info_type_id IN (
        SELECT id FROM info_type WHERE info = 'Box Office'
    )
),
FilteredMovies AS (
    SELECT 
        rm.title_id,
        rm.title,
        rm.production_year,
        COALESCE(SUM(CASE WHEN ci.person_role_id IS NOT NULL THEN 1 ELSE 0 END), 0) AS cast_count,
        STRING_AGG(DISTINCT CONCAT(ka.name, ' as ', rt.role), ', ') AS cast_names
    FROM RankedMovies rm
    LEFT JOIN complete_cast cc ON rm.title_id = cc.movie_id
    LEFT JOIN cast_info ci ON cc.subject_id = ci.id
    LEFT JOIN aka_name ka ON ci.person_id = ka.person_id
    LEFT JOIN role_type rt ON ci.role_id = rt.id
    WHERE rm.rank <= 5
    GROUP BY rm.title_id, rm.title, rm.production_year
)
SELECT 
    fm.title,
    fm.production_year,
    fm.cast_count,
    COALESCE(fm.cast_names, 'No Cast') AS cast_members,
    CASE 
        WHEN fm.cast_count > 0 THEN 'Featured'
        ELSE 'Not Featured'
    END AS feature_status
FROM FilteredMovies fm
ORDER BY fm.production_year DESC, fm.cast_count DESC;
