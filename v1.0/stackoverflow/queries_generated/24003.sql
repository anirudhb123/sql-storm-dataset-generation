WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AcceptedAnswerId,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY EXTRACT(YEAR FROM p.CreationDate) ORDER BY p.Score DESC) as RankInYear
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Questions only
        AND p.Score > 0
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        COALESCE(SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END), 0) AS AcceptedAnswerCount,
        SUM(v.BountyAmount) AS TotalBounties,
        SUM(v.CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvotesCount,
        SUM(v.CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvotesCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.Reputation
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        MIN(ph.CreationDate) AS ClosedDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post Closed
    GROUP BY 
        ph.PostId
),
PostSummary AS (
    SELECT 
        rp.Id,
        rp.Title,
        u.UserId,
        u.Reputation,
        COALESCE(cl.ClosedDate, 'No Closure') AS ClosureDate,
        rp.Score,
        rp.ViewCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Users u ON rp.AcceptedAnswerId = u.Id
    LEFT JOIN 
        ClosedPosts cl ON rp.Id = cl.PostId
)
SELECT 
    ps.Title,
    ps.Reputation,
    ps.ClosureDate,
    ps.Score,
    ps.ViewCount,
    CASE 
        WHEN ps.ViewCount > 100 AND ps.Score > 10 THEN 'Hot'
        WHEN ps.ViewCount < 10 THEN 'Neglected'
        ELSE 'Normal'
    END AS PostStatus,
    STRING_AGG(DISTINCT t.TagName, ', ') AS AssociatedTags
FROM 
    PostSummary ps
LEFT JOIN 
    Tags t ON ps.Id = t.ExcerptPostId
GROUP BY 
    ps.Title, ps.Reputation, ps.ClosureDate, ps.Score, ps.ViewCount
ORDER BY 
    ps.Reputation DESC, ps.Score DESC
LIMIT 10;

This query includes multiple advanced SQL constructs such as Common Table Expressions (CTEs), window functions, string aggregations, and conditional logic. It benchmarks performance through filtering and sorting questions, integrating user statistics and closure history, resulting in a summary of posts under different classifications. Additionally, it handles NULL logic with the use of COALESCE for displaying 'No Closure' when applicable.
