WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only questions
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(v.VoteTypeId = 2) - SUM(v.VoteTypeId = 3), 0) AS NetVotes,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, 
        u.DisplayName, 
        u.Reputation
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate,
        STRING_AGG(DISTINCT CAST(ph.Comment AS varchar), ', ') AS EditComments
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6, 10, 11) -- Edit Title, Edit Body, Edit Tags, Post Closed, Post Reopened
    GROUP BY 
        ph.PostId
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        SUM(COALESCE(h.EditCount, 0)) AS TotalEdits
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        PostHistorySummary h ON p.Id = h.PostId
    GROUP BY 
        u.Id, 
        u.DisplayName, 
        u.Reputation
    HAVING 
        SUM(COALESCE(p.Score, 0)) > 100 -- Only consider users with significant score
),
PostAnalytics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        ue.Reputation AS UserReputation,
        ue.NetVotes,
        phs.EditCount,
        phs.LastEditDate,
        phs.EditComments,
        ROW_NUMBER() OVER (ORDER BY rp.Score DESC, rp.ViewCount DESC) AS PopularityRank
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON rp.OwnerUserId = u.Id
    JOIN 
        UserEngagement ue ON ue.UserId = u.Id
    LEFT JOIN 
        PostHistorySummary phs ON rp.PostId = phs.PostId
)
SELECT 
    pa.PostId,
    pa.Title,
    pa.CreationDate,
    pa.Score,
    pa.UserReputation,
    pa.NetVotes,
    pa.EditCount,
    pa.LastEditDate,
    pa.EditComments,
    tu.DisplayName AS TopUser,
    tu.TotalScore,
    tu.TotalEdits
FROM 
    PostAnalytics pa
LEFT JOIN 
    TopUsers tu ON pa.UserReputation = tu.Reputation -- Joining to show related top users
WHERE 
    pa.PopularityRank <= 10 -- Top 10 most popular questions
ORDER BY 
    pa.Score DESC, 
    pa.CreationDate DESC;
