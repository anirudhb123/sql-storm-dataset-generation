WITH PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.UserId) AS UniqueVoters,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        JSON_AGG(DISTINCT t.TagName) AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS tag ON tag IS NOT NULL
    LEFT JOIN 
        Tags t ON t.TagName = tag
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        CommentCount,
        UniqueVoters,
        UpVotes,
        DownVotes,
        Tags,
        RANK() OVER (ORDER BY Score DESC) AS Rank
    FROM 
        PostMetrics
)
SELECT 
    *,
    CASE 
        WHEN UniqueVoters > 50 THEN 'Highly Engaged'
        WHEN UniqueVoters BETWEEN 20 AND 50 THEN 'Moderately Engaged'
        ELSE 'Less Engaged'
    END AS EngagementLevel
FROM 
    TopPosts
WHERE 
    Rank <= 10
ORDER BY 
    Score DESC, CreationDate DESC;
