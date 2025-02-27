WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year' 
        AND p.PostTypeId = 1
), UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(v.BountyAmount) AS TotalBounties
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    GROUP BY 
        u.Id, u.Reputation
)
SELECT 
    p.Title,
    p.Score,
    p.ViewCount,
    p.AnswerCount,
    u.DisplayName,
    us.Reputation,
    us.QuestionCount,
    us.TotalBounties,
    COALESCE(ph.Comment, 'No comments made on the post') AS LatestComment,
    COALESCE(TL.TagList, 'No tags') AS Tags
FROM 
    RankedPosts p
INNER JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON c.PostId = p.Id
LEFT JOIN 
    PostHistory ph ON ph.PostId = p.Id AND ph.CreationDate = (
        SELECT MAX(CreationDate)
        FROM PostHistory
        WHERE PostId = p.Id
    )
LEFT JOIN (
    SELECT 
        pt.Id AS PostId,
        STRING_AGG(t.TagName, ', ') AS TagList
    FROM 
        Posts pt
    JOIN 
        UNNEST(STRING_TO_ARRAY(pt.Tags, '>')) AS tag ON tag IS NOT NULL
    JOIN 
        Tags t ON t.TagName = TRIM(both '<>' FROM tag)
    GROUP BY 
        pt.Id
) TL ON TL.PostId = p.Id
JOIN 
    UserStats us ON us.UserId = u.Id
WHERE 
    p.PostRank <= 3
ORDER BY 
    p.Score DESC, p.ViewCount DESC;
