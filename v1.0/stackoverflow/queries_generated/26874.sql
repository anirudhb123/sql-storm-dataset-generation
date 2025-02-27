WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        MAX(v.CreationDate) AS LastVoteDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id AND a.PostTypeId = 2
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.PostTypeId = 1 -- Only Questions
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags
),
PopularPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.Tags,
        rp.CommentCount,
        rp.AnswerCount,
        rp.LastVoteDate
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank = 1 AND rp.CommentCount > 5 -- Only popular posts with more than 5 comments
)
SELECT 
    pp.PostId,
    pp.Title,
    pp.CommentCount,
    pp.AnswerCount,
    pp.LastVoteDate,
    t.TagName,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation,
    (SELECT 
         STRING_AGG(DISTINCT t2.TagName, ', ')
     FROM 
         Posts p2
     JOIN 
         Tags t2 ON t2.Id = ANY (string_to_array(p2.Tags, ',')) -- Process tags for the specific post
     WHERE 
         p2.Id = pp.PostId) AS RelatedTags
FROM 
    PopularPosts pp
JOIN 
    Users u ON u.Id = (SELECT OwnerUserId FROM Posts WHERE Id = pp.PostId)
JOIN 
    Tags t ON t.Id = ANY (string_to_array(pp.Tags, ','))
ORDER BY 
    pp.LastVoteDate DESC, pp.PostId;
