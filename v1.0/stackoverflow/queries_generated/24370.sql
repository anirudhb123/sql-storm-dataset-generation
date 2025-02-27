WITH RankedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM 
        Users
    WHERE 
        Reputation IS NOT NULL
), 
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS UpVoteCount,
        COUNT(DISTINCT CASE WHEN v.VoteTypeId = 3 THEN v.Id END) AS DownVoteCount,
        AVG(v.VoteTypeId) AS AverageVoteType, -- average between Up and Down votes (1= Up, 2= Down)
        COUNT(DISTINCT hl.RelatedPostId) AS LinkedPostCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        PostLinks hl ON p.Id = hl.PostId
    WHERE 
        p.CreationDate >= '2020-01-01'
    GROUP BY 
        p.Id, p.OwnerUserId
), 
TagCounts AS (
    SELECT 
        p.Tags,
        COUNT(DISTINCT t.Id) AS TagCount
    FROM 
        Posts p
    JOIN 
        Tags t ON t.TagName = ANY (string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><'))
    GROUP BY 
        p.Tags
), 
ComplexPostStats AS (
    SELECT 
        ps.PostId,
        ps.OwnerUserId,
        ps.CommentCount,
        ps.UpVoteCount,
        ps.DownVoteCount,
        ps.AverageVoteType,
        tc.TagCount,
        COALESCE(ph.ClosedDate, '9999-12-31') AS ClosedDate -- Coalesce for outer join case
    FROM 
        PostStatistics ps
    LEFT JOIN 
        (SELECT 
            p.Id AS PostId, 
            MIN(ph.CreationDate) AS ClosedDate
        FROM 
            Posts p
        JOIN 
            PostHistory ph ON p.Id = ph.PostId
        WHERE 
            ph.PostHistoryTypeId = 10 -- Closed Type
        GROUP BY 
            p.Id) ph ON ps.PostId = ph.PostId
    LEFT JOIN 
        TagCounts tc ON ps.PostId = tc.Tags
), 
UserPostSummary AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT ps.PostId) AS TotalPosts,
        SUM(CASE WHEN ps.CommentCount > 3 THEN 1 ELSE 0 END) AS HighCommentPosts,
        COALESCE(SUM(ps.UpVoteCount - ps.DownVoteCount), 0) AS NetVotes
    FROM 
        RankedUsers u
    LEFT JOIN 
        ComplexPostStats ps ON u.Id = ps.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
)

SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.TotalPosts,
    ups.HighCommentPosts,
    ups.NetVotes,
    RANK() OVER (ORDER BY ups.NetVotes DESC) AS UserRank,
    CASE
        WHEN ups.NetVotes > 50 THEN 'High Engagement'
        WHEN ups.NetVotes BETWEEN 20 AND 50 THEN 'Moderate Engagement'
        ELSE 'Low Engagement'
    END AS EngagementCategory
FROM 
    UserPostSummary ups
WHERE 
    ups.TotalPosts > 10
ORDER BY 
    ups.NetVotes DESC, ups.TotalPosts ASC;
