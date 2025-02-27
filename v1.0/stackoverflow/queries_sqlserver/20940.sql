
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS Rank,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Posts p 
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    CROSS APPLY (
        SELECT 
            value AS TagName
        FROM 
            STRING_SPLIT(p.Tags, '><')
    ) AS t 
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, '2024-10-01 12:34:56') 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, pt.Name
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(c.Id) AS CommentCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    GROUP BY 
        u.Id
),
PostStatistics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        ue.UpVotes,
        ue.DownVotes,
        ue.CommentCount,
        COALESCE(ue.UpVotes, 0) AS EffectiveUpVotes,
        COALESCE(ROUND((CAST(rp.Score AS FLOAT) / NULLIF(rp.ViewCount, 0)) * 100, 2), 0) AS ScorePerView
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UserEngagement ue ON ue.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId)
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.EffectiveUpVotes,
    ps.DownVotes,
    ps.CommentCount,
    ps.ScorePerView,
    CASE 
        WHEN ps.ScorePerView > 5 THEN 'Highly Engaged'
        WHEN ps.ScorePerView > 2 THEN 'Moderately Engaged'
        ELSE 'Low Engagement' 
    END AS EngagementLevel,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
FROM 
    PostStatistics ps
JOIN 
    Posts p ON ps.PostId = p.Id
CROSS APPLY (
    SELECT 
        value AS TagName
    FROM 
        STRING_SPLIT(p.Tags, '><')
) AS t 
WHERE 
    ps.ScorePerView IS NOT NULL
GROUP BY 
    ps.PostId, ps.Title, ps.CreationDate, ps.Score, ps.ViewCount, ps.EffectiveUpVotes, ps.DownVotes, ps.CommentCount, ps.ScorePerView
ORDER BY 
    ps.ScorePerView DESC, ps.CreationDate DESC
OFFSET 0 ROWS 
FETCH NEXT 100 ROWS ONLY;
