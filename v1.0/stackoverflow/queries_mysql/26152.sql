
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        (LENGTH(p.Tags) - LENGTH(REPLACE(p.Tags, '><', ''))) + 1 AS TagCount,
        COALESCE(u.DisplayName, 'Deleted User') AS OwnerDisplayName,
        COALESCE(u.Reputation, 0) AS OwnerReputation,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.Tags, p.CreationDate, p.Score, p.ViewCount, u.DisplayName, u.Reputation
),
TopPosts AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY Score DESC, ViewCount DESC, TagCount DESC) AS PostRank
    FROM 
        RankedPosts
),
FinalStats AS (
    SELECT 
        PostId,
        Title,
        OwnerDisplayName,
        OwnerReputation,
        Score,
        ViewCount,
        TagCount,
        CommentCount,
        UpVoteCount,
        DownVoteCount,
        PostRank
    FROM 
        TopPosts
    WHERE 
        PostRank <= 10  
)
SELECT 
    PostId,
    Title,
    OwnerDisplayName,
    OwnerReputation,
    Score,
    ViewCount,
    TagCount,
    CommentCount,
    UpVoteCount,
    DownVoteCount,
    (CAST(UpVoteCount AS DECIMAL) / NULLIF(CommentCount, 0)) AS UpVoteToCommentRatio,
    (CAST(DownVoteCount AS DECIMAL) / NULLIF(CommentCount, 0)) AS DownVoteToCommentRatio
FROM 
    FinalStats
ORDER BY 
    PostRank;
