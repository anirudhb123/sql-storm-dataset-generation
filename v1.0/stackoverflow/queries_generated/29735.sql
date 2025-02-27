WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only questions
),
TopRankedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.Tags,
        rp.CreationDate,
        rp.ViewCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank = 1
),
PostDetails AS (
    SELECT 
        tp.*,
        u.DisplayName AS OwnerDisplayName,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = tp.PostId) AS CommentCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = tp.PostId AND v.VoteTypeId = 2) AS UpvoteCount, -- UpMod votes
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = tp.PostId AND v.VoteTypeId = 3) AS DownvoteCount -- DownMod votes
    FROM 
        TopRankedPosts tp
    JOIN 
        Users u ON tp.OwnerUserId = u.Id
),
CommentsDetail AS (
    SELECT 
        pd.PostId,
        STRING_AGG(c.Text, ' | ') AS AllComments,
        COUNT(c.Id) AS TotalComments
    FROM 
        PostDetails pd
    LEFT JOIN 
        Comments c ON c.PostId = pd.PostId
    GROUP BY 
        pd.PostId
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.Body,
    pd.Tags,
    pd.CreationDate,
    pd.ViewCount,
    pd.CommentCount,
    pd.UpvoteCount,
    pd.DownvoteCount,
    cd.AllComments,
    cd.TotalComments
FROM 
    PostDetails pd
LEFT JOIN 
    CommentsDetail cd ON pd.PostId = cd.PostId
ORDER BY 
    pd.ViewCount DESC
FETCH FIRST 10 ROWS ONLY;
