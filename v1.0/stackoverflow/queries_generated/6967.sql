WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVoteCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY 
        p.Id, u.DisplayName
),
AggregatedData AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        OwnerDisplayName,
        CommentCount,
        UpVoteCount,
        DownVoteCount,
        RANK() OVER (ORDER BY Score DESC, ViewCount DESC) AS PopularityRank
    FROM 
        RankedPosts
)
SELECT 
    a.PostId,
    a.Title,
    a.CreationDate,
    a.Score,
    a.ViewCount,
    a.OwnerDisplayName,
    a.CommentCount,
    a.UpVoteCount,
    a.DownVoteCount,
    a.PopularityRank,
    pt.Name AS PostTypeName,
    CASE 
        WHEN a.PopularityRank <= 10 THEN 'Top Posts'
        WHEN a.PopularityRank <= 50 THEN 'Popular Posts'
        ELSE 'Regular Posts'
    END AS PostCategory
FROM 
    AggregatedData a
JOIN 
    PostTypes pt ON a.PopularityRank <= 50
WHERE 
    a.Rank = 1
ORDER BY 
    a.PopularityRank;
