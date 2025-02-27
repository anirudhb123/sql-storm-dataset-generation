WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.LastActivityDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS PostOwner,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags,
        COALESCE((
            SELECT COUNT(*)
            FROM Comments c
            WHERE c.PostId = p.Id
        ), 0) AS CommentCount,
        COALESCE((
            SELECT COUNT(*)
            FROM Posts a
            WHERE a.ParentId = p.Id
        ), 0) AS AnswerCount,
        COALESCE((
            SELECT AVG(v.BountyAmount)
            FROM Votes v
            WHERE v.PostId = p.Id AND v.VoteTypeId IN (8, 9)
        ), 0) AS AverageBounty
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Tags t ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><'))
    WHERE 
        p.PostTypeId = 1  -- Questions only
    GROUP BY 
        p.Id, u.DisplayName
),
PostActivity AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.PostOwner,
        pd.CreationDate,
        pd.LastActivityDate,
        pd.ViewCount,
        pd.Score,
        pd.CommentCount,
        pd.AnswerCount,
        pd.AverageBounty,
        (SELECT 
            COUNT(*) 
         FROM 
            PostHistory ph 
         WHERE 
            ph.PostId = pd.PostId 
          AND 
            ph.CreationDate >= NOW() - INTERVAL '30 days') AS RecentEdits,
        (SELECT 
            COUNT(*) 
         FROM 
            Votes v 
         WHERE 
            v.PostId = pd.PostId AND v.VoteTypeId = 2) AS Upvotes,
        (SELECT 
            COUNT(*) 
         FROM 
            Votes v 
         WHERE 
            v.PostId = pd.PostId AND v.VoteTypeId = 3) AS Downvotes
    FROM 
        PostDetails pd
)

SELECT 
    PostId,
    Title,
    PostOwner,
    CreationDate,
    LastActivityDate,
    ViewCount,
    Score,
    AverageBounty,
    CommentCount,
    AnswerCount,
    RecentEdits,
    Upvotes,
    Downvotes,
    (ViewCount + Score + CommentCount + AnswerCount + AverageBounty - Downvotes + RecentEdits) AS BenchmarkScore
FROM 
    PostActivity
ORDER BY 
    BenchmarkScore DESC
LIMIT 10;
