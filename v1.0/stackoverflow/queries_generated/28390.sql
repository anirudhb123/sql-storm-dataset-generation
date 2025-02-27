WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.AnswerCount,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(v.Id) AS VoteCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2 -- Upvotes
    WHERE 
        p.PostTypeId = 1 -- Questions only
    GROUP BY 
        p.Id, u.DisplayName
),
FilteredPosts AS (
    SELECT 
        rp.*,
        ROW_NUMBER() OVER (PARTITION BY LEFT(rp.Title, 10) ORDER BY rp.VoteCount DESC) AS TitleRank 
    FROM 
        RankedPosts rp
    WHERE 
        rp.ViewCount > 100
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.OwnerDisplayName,
    fp.VoteCount,
    fp.CreationDate,
    fp.AnswerCount,
    fp.ViewCount
FROM 
    FilteredPosts fp
WHERE 
    fp.TitleRank = 1 -- Select top ranked post per unique title starting with the same prefix
ORDER BY 
    fp.VoteCount DESC, 
    fp.CreationDate DESC -- Sort by vote count and latest creation date
LIMIT 10; -- Limit to top 10 results
