WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.Tags,
        u.DisplayName AS AuthorDisplayName,
        COALESCE(AVG(vt.Id), 0) AS AverageVoteType,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
        LEFT JOIN Users u ON p.OwnerUserId = u.Id
        LEFT JOIN Votes vt ON p.Id = vt.PostId
        LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 -- Only questions
        AND p.CreationDate >= NOW() - INTERVAL '1 year' -- Posts from the last year
    GROUP BY 
        p.Id, u.DisplayName
), FilteredPosts AS (
    SELECT 
        rp.*,
        STRING_AGG(pt.Name, ', ') AS PostTypeNames -- Join with PostTypes
    FROM 
        RankedPosts rp
        JOIN PostTypes pt ON rp.PostId % pt.Id = 0 -- Just for demonstration, a modulo condition (not real use-case)
    GROUP BY 
        rp.PostId
), PopularPosts AS (
    SELECT 
        fp.*,
        ROW_NUMBER() OVER (ORDER BY fp.ViewCount DESC) AS ViewRank,
        ROW_NUMBER() OVER (ORDER BY fp.AverageVoteType DESC) AS VoteRank
    FROM 
        FilteredPosts fp
)
SELECT 
    pp.PostId,
    pp.Title,
    pp.Body,
    pp.CreationDate,
    pp.ViewCount,
    pp.Score,
    pp.Tags,
    pp.AuthorDisplayName,
    pp.ViewRank,
    pp.VoteRank,
    pp.CommentCount
FROM 
    PopularPosts pp
WHERE 
    pp.ViewRank <= 10 -- Top 10 by views
    AND pp.VoteRank <= 10 -- Top 10 by average vote type
ORDER BY 
    pp.ViewCount DESC, pp.AverageVoteType DESC; 
