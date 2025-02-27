WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only questions
        AND p.Score > 0 -- Only questions with a score
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        SUM(COALESCE(b.Class, 0)) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate AS HistoryDate,
        CONCAT(u.DisplayName, ': ', ph.Comment) AS HistoryComment
    FROM 
        PostHistory ph
    JOIN 
        Users u ON ph.UserId = u.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Only closed and reopened events
),
TopRankedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        us.UserId,
        us.DisplayName,
        us.QuestionCount,
        us.TotalScore,
        us.TotalBadges
    FROM 
        RankedPosts rp
    JOIN 
        UserStats us ON rp.OwnerUserId = us.UserId
    WHERE 
        rp.PostRank <= 3 -- Top 3 posts per user
)
SELECT 
    trp.Title AS PostTitle,
    trp.Score AS PostScore,
    trp.ViewCount AS PostViewCount,
    trp.DisplayName AS OwnerName,
    trp.QuestionCount AS OwnerTotalQuestions,
    trp.TotalScore AS OwnerTotalScore,
    trp.TotalBadges AS OwnerTotalBadges,
    COALESCE(phd.HistoryComment, 'No closure history') AS ClosureHistory
FROM 
    TopRankedPosts trp
LEFT JOIN 
    PostHistoryDetails phd ON trp.PostId = phd.PostId
ORDER BY 
    trp.Score DESC, trp.ViewCount DESC;

This SQL query performs several operations:

1. **CTE - RankedPosts**: Rank questions by score for each user, selecting only those with a positive score.
2. **CTE - UserStats**: Collect statistics for each user, counting their questions, summing their total scores from posts, and counting their badges.
3. **CTE - PostHistoryDetails**: Extract only relevant history details for posts that have been closed or reopened.
4. **CTE - TopRankedPosts**: Combine ranked posts with user statistics, fetching only the top-ranked posts for each user.
5. **Final Selection**: Produce a report that shows the title, score, view count of the top-ranked posts, and user stats, including closure history if available.

The query utilizes various SQL constructs such as CTEs, outer joins, aggregation, and string concatenation, while also handling NULL values using `COALESCE`.
