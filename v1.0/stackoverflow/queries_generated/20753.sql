WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.ClosedDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount,
        COALESCE(pht.Dto, 0) AS TotalEdits,
        COALESCE(pb.BountyAmount, 0) AS BountyAmount
    FROM 
        RankedPosts rp
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS Dto 
        FROM 
            PostHistory 
        WHERE 
            PostHistoryTypeId IN (5, 6, 24) -- Body edit, Tags edit, Suggested Edit Applied
        GROUP BY 
            PostId
    ) pht ON rp.PostId = pht.PostId
    LEFT JOIN (
        SELECT 
            PostId,
            SUM(BountyAmount) AS BountyAmount 
        FROM 
            Votes 
        WHERE 
            VoteTypeId IN (8, 9) -- BountyStart, BountyClose
        GROUP BY 
            PostId
    ) pb ON rp.PostId = pb.PostId
    WHERE 
        rp.Rank <= 10
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.Score,
    tp.ViewCount,
    tp.AnswerCount,
    CASE 
        WHEN tp.TotalEdits > 0 THEN 'Edited'
        ELSE 'Not Edited'
    END AS EditStatus,
    CASE 
        WHEN tp.BountyAmount > 0 THEN 'Has Bounty'
        ELSE 'No Bounty'
    END AS BountyStatus,
    COALESCE(ut.UserIds, 'No users') AS VoterUsers,
    COALESCE(ut.VoteCount, 0) AS TotalVotes
FROM 
    TopPosts tp
LEFT JOIN (
    SELECT 
        PostId,
        STRING_AGG(DISTINCT u.DisplayName, ', ') AS UserIds,
        COUNT(*) AS VoteCount
    FROM 
        Votes v
    JOIN 
        Users u ON v.UserId = u.Id
    GROUP BY 
        v.PostId
) ut ON tp.PostId = ut.PostId
ORDER BY 
    tp.Score DESC, 
    tp.ViewCount DESC;
This SQL query achieves the following:

1. **Common Table Expressions (CTEs)**: Two CTEs are used: `RankedPosts` to rank posts by score and view count, and `TopPosts` to gather additional statistics, including edit counts and bounty amounts.

2. **Window Functions**: The `ROW_NUMBER()` window function is utilized to rank posts based on their types.

3. **LEFT JOINs**: Several LEFT JOINs aggregate data from the `PostHistory` and `Votes` tables to fetch metrics on edits and bounties.

4. **Conditional Logic**: CASE statements determine whether a post is edited or has bounty status, enriching the output with meaningful labels.

5. **Aggregation and NULL Handling**: The `COALESCE` function is used to manage NULLs, ensuring the query returns human-readable values irrespective of the post's conditions.

6. **String Aggregation**: The `STRING_AGG` function gathers voter usernames into a single, comma-separated string, showcasing the relational aspect of the voting system.

7. **Complex Filtering**: It filters posts created in the last year, further narrowing down to the top 10 posts of each type.

This query could be used for performance benchmarking due to its complexity and the diverse SQL constructs involved.
