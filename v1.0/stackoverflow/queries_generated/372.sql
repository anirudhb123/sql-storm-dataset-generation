WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY COUNT(DISTINCT v.Id) DESC) AS RankWithinType
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > CURRENT_DATE - INTERVAL '1 year' 
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId, p.PostTypeId
),
TopPostDetails AS (
    SELECT 
        rp.Id,
        rp.Title,
        u.DisplayName AS OwnerDisplayName,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes,
        CASE 
            WHEN rp.UpVotes > rp.DownVotes THEN 'Positive'
            WHEN rp.DownVotes > rp.UpVotes THEN 'Negative'
            ELSE 'Neutral'
        END AS Sentiment
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON rp.OwnerUserId = u.Id
    WHERE 
        rp.RankWithinType = 1
)
SELECT 
    tpd.Title,
    tpd.OwnerDisplayName,
    tpd.CommentCount,
    tpd.UpVotes,
    tpd.DownVotes,
    tpd.Sentiment,
    COALESCE(b.Name, 'No Badge') AS UserBadge,
    COUNT(DISTINCT pl.RelatedPostId) AS RelatedPostsCount
FROM 
    TopPostDetails tpd
LEFT JOIN 
    Badges b ON tpd.OwnerUserId = b.UserId AND b.Class = 1  -- Gold Badge
LEFT JOIN 
    PostLinks pl ON tpd.Id = pl.PostId
GROUP BY 
    tpd.Title, tpd.OwnerDisplayName, tpd.CommentCount, tpd.UpVotes, tpd.DownVotes, tpd.Sentiment, b.Name
ORDER BY 
    tpd.UpVotes DESC, tpd.DownVotes ASC;
