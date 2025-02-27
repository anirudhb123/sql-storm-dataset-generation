
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY GROUP_CONCAT(tag.TagName ORDER BY tag.TagName SEPARATOR ',') ORDER BY p.ViewCount DESC) AS Rank,
        GROUP_CONCAT(tag.TagName ORDER BY tag.TagName SEPARATOR ',') AS CombinedTags
    FROM 
        Posts p
    LEFT JOIN 
        (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS TagName
         FROM 
         (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
          SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL 
          SELECT 9 UNION ALL SELECT 10) numbers
         INNER JOIN Posts p ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1) AS tag ON TRUE
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, p.Score, p.Tags
),
TopRankedPosts AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.ViewCount,
        rp.Score,
        rp.CombinedTags
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
),
PostWithVotes AS (
    SELECT 
        trp.Id AS PostId,
        trp.Title,
        trp.ViewCount,
        trp.Score,
        trp.CombinedTags,
        COALESCE(v.TotalUpvotes, 0) AS TotalUpvotes,
        COALESCE(v.TotalDownvotes, 0) AS TotalDownvotes
    FROM 
        TopRankedPosts trp
    LEFT JOIN (
        SELECT 
            PostId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes
        FROM 
            Votes
        GROUP BY 
            PostId
    ) v ON trp.Id = v.PostId
)
SELECT 
    pwv.PostId,
    pwv.Title,
    pwv.ViewCount,
    pwv.Score,
    pwv.CombinedTags,
    pwv.TotalUpvotes,
    pwv.TotalDownvotes,
    CASE 
        WHEN pwv.TotalUpvotes - pwv.TotalDownvotes > 0 THEN 'Positive'
        WHEN pwv.TotalUpvotes - pwv.TotalDownvotes < 0 THEN 'Negative'
        ELSE 'Neutral'
    END AS VoteSentiment
FROM 
    PostWithVotes pwv
ORDER BY 
    pwv.TotalUpvotes DESC, pwv.Score DESC;
