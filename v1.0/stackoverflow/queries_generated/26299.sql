WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.ViewCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotes,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS RankByRecency,
        ROW_NUMBER() OVER (ORDER BY p.Score DESC, p.ViewCount DESC) AS OverallRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '30 days' 
        AND p.ViewCount > 50
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.ViewCount
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        Tags,
        ViewCount,
        CommentCount,
        UpVotes,
        DownVotes,
        OverallRank
    FROM 
        RankedPosts
    WHERE 
        RankByRecency <= 10
),
FilteredTags AS (
    SELECT 
        DISTINCT UNNEST(STRING_TO_ARRAY(Tags, ',')) AS Tag
    FROM 
        TopPosts
)
SELECT 
    t.Tag, 
    COUNT(tp.PostId) AS PostsCount,
    SUM(tp.ViewCount) AS TotalViewCount,
    SUM(tp.CommentCount) AS TotalCommentCount,
    SUM(tp.UpVotes) AS TotalUpVotes,
    SUM(tp.DownVotes) AS TotalDownVotes
FROM 
    FilteredTags t
JOIN 
    TopPosts tp ON tp.Tags LIKE '%' || t.Tag || '%'
GROUP BY 
    t.Tag
ORDER BY 
    TotalViewCount DESC
LIMIT 5;
