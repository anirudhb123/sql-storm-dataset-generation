WITH PostTagCounts AS (
    SELECT 
        p.Id AS PostId,
        COUNT(DISTINCT unnest(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><'))) AS TagCount,
        MAX(p.CreationDate) AS LatestCreationDate
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Questions only
    GROUP BY 
        p.Id
),

UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalQuestions,
        COUNT(DISTINCT ph.Id) AS TotalEdits
    FROM 
        Users u
    JOIN 
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN 
        PostHistory ph ON ph.UserId = u.Id AND ph.PostId IN (SELECT PostId FROM PostTagCounts)
    GROUP BY 
        u.Id
),

TopUsers AS (
    SELECT 
        u.UserId,
        u.Reputation,
        u.TotalQuestions,
        u.TotalEdits,
        CASE 
            WHEN u.TotalQuestions >= 10 THEN 'Expert' 
            WHEN u.TotalQuestions BETWEEN 5 AND 9 THEN 'Intermediate' 
            ELSE 'Novice' 
        END AS UserLevel
    FROM 
        UserReputation u
    WHERE 
        u.Reputation >= 100
    ORDER BY 
        u.Reputation DESC
    LIMIT 10
)

SELECT 
    tt.UserId,
    tt.Reputation,
    tt.TotalQuestions,
    tt.TotalEdits,
    tt.UserLevel,
    ptc.TagCount,
    ptc.LatestCreationDate
FROM 
    TopUsers tt
JOIN 
    PostTagCounts ptc ON tt.UserId IN (SELECT OwnerUserId FROM Posts WHERE PostTypeId = 1)
ORDER BY 
    ptc.TagCount DESC, 
    tt.Reputation DESC;
