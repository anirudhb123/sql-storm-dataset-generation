WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title,
        p.Score,
        p.CreationDate,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- We're only interested in questions
), TagStatistics AS (
    SELECT 
        UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS Tag,
        COUNT(*) AS TagCount
    FROM 
        Posts p 
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        Tag
), PopularUsers AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounties
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) -- Count only BountyStart and BountyClose votes
    GROUP BY 
        u.Id
    HAVING 
        QuestionCount > 5 -- For users with more than 5 questions
), RecentPostHistory AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS HistoryDate,
        ph.PostHistoryTypeId,
        ph.UserDisplayName,
        ph.Comment
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.CreationDate >= NOW() - INTERVAL '30 days' 
        AND p.PostTypeId = 1 -- Only for questions
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.CreationDate,
    STRING_AGG(DISTINCT ts.Tag, ', ') AS Tags,
    pu.DisplayName AS PopularUser,
    pu.QuestionCount AS UserQuestionCount,
    pu.TotalBounties AS UserTotalBounties,
    rph.HistoryDate,
    rph.UserDisplayName AS Editor,
    rph.Comment
FROM 
    RankedPosts rp
LEFT JOIN 
    TagStatistics ts ON true
LEFT JOIN 
    PopularUsers pu ON rp.OwnerUserId = pu.UserId
LEFT JOIN 
    RecentPostHistory rph ON rp.PostId = rph.PostId
WHERE 
    rp.Rank <= 3 -- Get top 3 questions per user based on score
GROUP BY 
    rp.PostId, rp.Title, rp.Score, pu.DisplayName, pu.QuestionCount, pu.TotalBounties, rph.HistoryDate, rph.UserDisplayName, rph.Comment
ORDER BY 
    rp.CreationDate DESC;
