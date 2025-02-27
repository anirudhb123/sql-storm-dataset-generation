WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        tags.ListOfTags,
        ROW_NUMBER() OVER (ORDER BY p.CreationDate DESC) AS Rank,
        STRING_AGG(DISTINCT t.TagName, ', ') AS AssociatedTags
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN (
        SELECT 
            pt.PostId, 
            STRING_AGG(t.TagName, ', ') AS ListOfTags
        FROM 
            PostsTags pt
        JOIN 
            Tags t ON pt.TagId = t.Id
        GROUP BY 
            pt.PostId
    ) AS tags ON p.Id = tags.PostId
    WHERE 
        p.PostTypeId = 1 -- Questions only
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, u.DisplayName, p.ViewCount, p.AnswerCount, p.CommentCount
),
CommentContribution AS (
    SELECT 
        PostId, 
        SUM(CASE WHEN UserId IS NOT NULL THEN 1 ELSE 0 END) AS TotalComments,
        SUM(Score) AS TotalCommentScore
    FROM 
        Comments
    GROUP BY 
        PostId
),
CombinedData AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.OwnerDisplayName,
        rp.AssociatedTags,
        COALESCE(cc.TotalComments, 0) AS TotalComments,
        COALESCE(cc.TotalCommentScore, 0) AS TotalCommentScore,
        rp.Rank
    FROM 
        RankedPosts rp
    LEFT JOIN 
        CommentContribution cc ON rp.PostId = cc.PostId
)
SELECT 
    PostId, 
    Title, 
    OwnerDisplayName,
    CreationDate,
    AssociatedTags,
    TotalComments,
    TotalCommentScore,
    Rank
FROM 
    CombinedData
WHERE 
    TotalComments > 0
ORDER BY 
    Rank
LIMIT 10;
