WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.UserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ARRAY_AGG(t.TagName) AS Tags,
        ps.Reputation AS UserReputation
    FROM 
        Posts p
    JOIN 
        Users ps ON p.OwnerUserId = ps.Id
    LEFT JOIN 
        Posts t ON p.Id = t.Id
    GROUP BY 
        p.Id, ps.Reputation
),
HighScoringPosts AS (
    SELECT 
        pd.Title,
        pd.CreationDate,
        pd.Score,
        pd.ViewCount,
        us.DisplayName,
        us.UpVotes,
        us.DownVotes,
        pd.Tags
    FROM 
        PostDetails pd
    JOIN 
        UserStats us ON pd.UserId = us.UserId
    WHERE 
        pd.Score > (SELECT AVG(Score) FROM Posts) 
        AND pd.ViewCount > (SELECT AVG(ViewCount) FROM Posts)
)
SELECT 
    Title,
    CreationDate,
    Score,
    ViewCount,
    DisplayName,
    UpVotes,
    DownVotes,
    Tags 
FROM 
    HighScoringPosts 
ORDER BY 
    Score DESC, 
    ViewCount DESC 
LIMIT 20;
