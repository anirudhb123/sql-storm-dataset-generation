WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users U ON p.OwnerUserId = U.Id
    WHERE 
        p.PostTypeId = 1 -- Only questions
),
RecentActivity AS (
    SELECT 
        p.Id,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        MAX(c.CreationDate) AS LastCommentDate
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '30 days' -- Posts created in the last 30 days
    GROUP BY 
        p.Id
),
CombinedData AS (
    SELECT
        r.Title,
        r.OwnedDisplayName,
        r.CreationDate,
        r.Score,
        r.ViewCount,
        ra.CommentCount,
        ra.VoteCount,
        ra.LastCommentDate,
        DENSE_RANK() OVER (ORDER BY r.Score DESC) AS OverallRank
    FROM 
        RankedPosts r
    LEFT JOIN 
        RecentActivity ra ON r.Id = ra.Id
    WHERE 
        r.Rank = 1 -- Only top post per user
),
TopPosts AS (
    SELECT 
        Title,
        OwnerDisplayName,
        CreationDate,
        Score,
        ViewCount,
        CommentCount,
        VoteCount,
        LastCommentDate,
        OverallRank
    FROM 
        CombinedData
    WHERE 
        OverallRank <= 50  -- Top 50 posts
)
SELECT 
    TP.Title,
    TP.OwnerDisplayName,
    TO_CHAR(TP.CreationDate, 'YYYY-MM-DD') AS FormattedCreationDate,
    TP.Score,
    TP.ViewCount,
    COALESCE(TP.CommentCount, 0) AS TotalComments,
    COALESCE(TP.VoteCount, 0) AS TotalVotes,
    CASE 
        WHEN TP.LastCommentDate IS NULL THEN 'No Comments'
        ELSE TO_CHAR(TP.LastCommentDate, 'YYYY-MM-DD HH24:MI:SS')
    END AS LastCommentDate
FROM 
    TopPosts TP
ORDER BY 
    TP.Score DESC, 
    TP.CreationDate DESC;
