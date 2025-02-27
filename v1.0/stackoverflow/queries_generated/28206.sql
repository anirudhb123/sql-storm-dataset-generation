WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(CASE WHEN c.Id IS NOT NULL THEN 1 END) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVoteCount,
        SUM(v.VoteTypeId = 3) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    INNER JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '30 days' 
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, u.DisplayName
),

PopularPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        CreationDate,
        ViewCount,
        OwnerDisplayName,
        CommentCount,
        UpVoteCount,
        DownVoteCount
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
)

SELECT 
    pp.PostId,
    pp.Title,
    pp.CreationDate,
    pp.ViewCount,
    pp.CommentCount,
    pp.UpVoteCount,
    pp.DownVoteCount,
    CASE 
        WHEN pp.UpVoteCount > pp.DownVoteCount THEN 'Positive Engagement'
        WHEN pp.UpVoteCount < pp.DownVoteCount THEN 'Negative Engagement'
        ELSE 'Neutral Engagement'
    END AS EngagementType
FROM 
    PopularPosts pp
ORDER BY 
    pp.ViewCount DESC, pp.CreationDate DESC;

