WITH RankedPosts AS (
    SELECT 
        p.Id as PostId,
        p.Title,
        p.Score,
        COUNT(c.Id) OVER (PARTITION BY p.Id) as CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) as rn
    FROM 
        Posts p
        LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId IN (1, 2) -- Consider only Questions and Answers
),

UserActivity AS (
    SELECT 
        u.Id as UserId,
        COALESCE(SUM(v.BountyAmount), 0) as TotalBountySpent,
        MAX(u.Reputation) as MaxReputation
    FROM 
        Users u
        LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
),

CloseReasons AS (
    SELECT 
        ph.PostId,
        string_agg(DISTINCT cr.Name, ', ') AS CloseReasonNames
    FROM 
        PostHistory ph
        JOIN CloseReasonTypes cr ON ph.Comment::int = cr.Id 
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post Closed
    GROUP BY 
        ph.PostId
),

FinalUserMetrics AS (
    SELECT 
        u.UserId,
        u.TotalBountySpent,
        u.MaxReputation,
        COALESCE(cr.CloseReasonNames, 'None') as CloseReasonsUsed,
        COUNT(rp.PostId) as PostCount,
        SUM(rp.CommentCount) as TotalComments
    FROM 
        UserActivity u
        LEFT JOIN RankedPosts rp ON u.UserId = rp.PostId
        LEFT JOIN CloseReasons cr ON rp.PostId = cr.PostId
    GROUP BY 
        u.UserId, u.TotalBountySpent, u.MaxReputation, cr.CloseReasonNames
),

ResultSet AS (
    SELECT 
        UserId,
        TotalBountySpent,
        MaxReputation,
        CloseReasonsUsed,
        PostCount,
        TotalComments,
        CASE 
            WHEN TotalComments < 5 THEN 'Low Engagement'
            WHEN TotalComments BETWEEN 5 AND 20 THEN 'Medium Engagement'
            ELSE 'High Engagement'
        END AS EngagementLevel
    FROM 
        FinalUserMetrics
    WHERE 
        TotalBountySpent > (SELECT AVG(TotalBountySpent) FROM UserActivity)
)

SELECT 
    f.UserId,
    f.TotalBountySpent,
    f.MaxReputation,
    f.CloseReasonsUsed,
    f.PostCount,
    f.TotalComments,
    f.EngagementLevel,
    COALESCE(p.Title, 'No Associated Title') as PostTitle,
    CASE 
        WHEN f.TotalComments IS NULL THEN 'Unknown'
        ELSE 'Known'
    END as CommentStatus
FROM 
    ResultSet f
    LEFT JOIN Posts p ON f.PostCount > 0 AND p.Id IN (SELECT PostId FROM RankedPosts WHERE rn = 1)
ORDER BY 
    f.TotalBountySpent DESC, 
    f.MaxReputation DESC;
