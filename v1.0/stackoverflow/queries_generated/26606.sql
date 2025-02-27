WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COALESCE(a.AcceptedAnswerId, 0) AS AcceptedAnswer,
        RANK() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS TagRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2  -- Joining posts to find accepted answers
    WHERE 
        p.PostTypeId = 1  -- Filter to include only questions
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, p.Score, u.DisplayName, a.AcceptedAnswerId
),
TopRankedPosts AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.Body, 
        rp.CreationDate, 
        rp.ViewCount, 
        rp.Score, 
        rp.OwnerDisplayName, 
        rp.CommentCount, 
        rp.AcceptedAnswer
    FROM 
        RankedPosts rp
    WHERE 
        rp.TagRank <= 5  -- Get top 5 posts per tag based on rank
)
SELECT 
    tr.Title,
    tr.Body,
    tr.CreationDate,
    tr.ViewCount,
    tr.Score,
    tr.OwnerDisplayName,
    tr.CommentCount,
    COALESCE(accepted.AnswerId, 'No Accepted Answer') AS AcceptedAnswerStatus,
    STRING_AGG(DISTINCT t.TagName, ', ') AS AssociatedTags
FROM 
    TopRankedPosts tr
LEFT JOIN 
    Posts p ON tr.PostId = p.Id
LEFT JOIN 
    PostLinks pl ON p.Id = pl.PostId
LEFT JOIN 
    Posts accepted ON accepted.Id = tr.AcceptedAnswer
LEFT JOIN 
    Tags t ON t.Id IN (SELECT UNNEST(string_to_array(p.Tags, '>'))::int)  -- Parsing and associating tags
GROUP BY 
    tr.PostId, tr.Title, tr.Body, tr.CreationDate, tr.ViewCount, tr.Score, tr.OwnerDisplayName, tr.CommentCount, accepted.AnswerId
ORDER BY 
    tr.Score DESC;
