WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        p.Score,
        p.Body,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        Tags t ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')::int[])
    WHERE 
        p.PostTypeId = 1 -- Selecting only Questions
    GROUP BY 
        p.Id
),
RecentActivity AS (
    SELECT 
        p.Id AS PostId,
        COALESCE(p.LastActivityDate, p.CreationDate) AS LastActivityDate,
        COUNT(c.Id) AS CommentCount,
        COUNT(h.Id) AS HistoryCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        PostHistory h ON h.PostId = p.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate > NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionsAsked,
        SUM(p.Score) AS TotalScore,
        SUM(v.BountyAmount) AS TotalBounties
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id AND p.PostTypeId = 1 
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    GROUP BY 
        u.Id
    ORDER BY 
        TotalScore DESC
    LIMIT 10 
),
PostMetrics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        ra.CommentCount,
        ra.HistoryCount,
        ra.LastActivityDate,
        tu.DisplayName AS TopUser,
        tu.QuestionsAsked,
        tu.TotalScore,
        tu.TotalBounties,
        rp.Tags
    FROM 
        RankedPosts rp
    JOIN 
        RecentActivity ra ON rp.PostId = ra.PostId
    LEFT JOIN 
        TopUsers tu ON tu.QuestionsAsked > 5 -- Joining to see top users who asked more than 5 questions
)
SELECT 
    pm.Title,
    pm.Score,
    pm.CommentCount,
    pm.HistoryCount,
    pm.LastActivityDate,
    pm.TopUser,
    pm.Tags,
    pm.QuestionsAsked,
    pm.TotalScore,
    pm.TotalBounties
FROM 
    PostMetrics pm
WHERE 
    pm.Score >= 10 -- Filtering for posts with a score of 10 or higher
ORDER BY 
    pm.LastActivityDate DESC, 
    pm.Score DESC; -- Order by the most recent activity and score
