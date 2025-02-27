WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        pt.Name AS PostType,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVoteCount, -- Upvotes
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVoteCount -- Downvotes
    FROM 
        Posts p
    LEFT JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= '2022-01-01' -- Filter for posts created in 2022 onwards
    GROUP BY 
        p.Id, p.Title, p.CreationDate, pt.Name, u.DisplayName
), 
PostStatistics AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        PostType,
        OwnerDisplayName,
        CommentCount,
        UpVoteCount,
        DownVoteCount,
        Row_Number() OVER (ORDER BY UpVoteCount DESC, CommentCount DESC) AS Rank
    FROM 
        RankedPosts
)

SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.PostType,
    ps.OwnerDisplayName,
    ps.CommentCount,
    ps.UpVoteCount,
    ps.DownVoteCount,
    ps.Rank,
    ROUND((ps.UpVoteCount::FLOAT / NULLIF((ps.UpVoteCount + ps.DownVoteCount), 0)) * 100, 2) AS UpVotePercentage -- Calculate UpVote Percentage
FROM 
    PostStatistics ps
WHERE 
    ps.Rank <= 10 -- Get top 10 ranked posts based on UpVoteCount
ORDER BY 
    ps.Rank;
