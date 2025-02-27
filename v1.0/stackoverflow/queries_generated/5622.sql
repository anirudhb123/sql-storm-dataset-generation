WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(v.VoteTypeId = 2) AS Upvotes,
        SUM(v.VoteTypeId = 3) AS Downvotes,
        AVG(CHAR_LENGTH(p.Body)) AS AveragePostLength,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 100
    GROUP BY 
        u.Id
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        STRING_TO_ARRAY(p.Tags, ',') AS tags ON TRUE
    LEFT JOIN 
        Tags t ON t.TagName = TRIM(both '<>' FROM unnest(tags))
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id
)
SELECT 
    us.DisplayName,
    us.Reputation,
    us.PostCount,
    us.Questions,
    us.Answers,
    us.Upvotes,
    us.Downvotes,
    us.AveragePostLength,
    us.BadgeCount,
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.Score,
    pd.ViewCount,
    pd.Tags
FROM 
    UserStats us
JOIN 
    PostDetails pd ON us.UserId = pd.OwnerUserId
ORDER BY 
    us.Reputation DESC, 
    pd.ViewCount DESC
LIMIT 100;
