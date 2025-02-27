WITH PostTagCounts AS (
    SELECT 
        p.Id AS PostId,
        COUNT(t.TagName) AS TagCount,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '> <'))::varchar[]) AS t(TagName)
    GROUP BY 
        p.Id
),

UserReputation AS (
    SELECT 
        u.Id AS UserId,
        SUM(b.Class) AS TotalBadges,
        AVG(u.Reputation) AS AvgReputation
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),

PostActivity AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.UserId) AS UniqueVoters,
        MAX(p.CreationDate) AS LastActivity
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId IN (1, 2) -- Questions and Answers
    GROUP BY 
        p.Id, p.Title
)

SELECT 
    pa.PostId,
    pa.Title,
    pa.CommentCount,
    pa.UniqueVoters,
    ptc.TagCount,
    ptc.Tags,
    ur.TotalBadges,
    ur.AvgReputation,
    pa.LastActivity
FROM 
    PostActivity pa
JOIN 
    PostTagCounts ptc ON pa.PostId = ptc.PostId
JOIN 
    Users u ON pa.PostId = u.Id
JOIN 
    UserReputation ur ON u.Id = ur.UserId
ORDER BY 
    pa.CommentCount DESC, ur.AvgReputation DESC
LIMIT 10;
