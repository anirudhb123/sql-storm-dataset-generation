WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Tags,
        COUNT(a.Id) AS AnswerCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS TagNames,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    LEFT JOIN 
        Tags t ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')::int[])
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Tags
),
ModifiedPostHistory AS (
    SELECT 
        ph.PostId,
        ph.UserDisplayName,
        ph.CreationDate,
        ph.Comment,
        ph.Text,
        PHT.Name AS PostHistoryTypeName
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes PHT ON ph.PostHistoryTypeId = PHT.Id
    WHERE 
        ph.CreationDate > NOW() - INTERVAL '30 days'
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(v.BountyAmount) AS TotalBounties,
        RANK() OVER (ORDER BY SUM(v.BountyAmount) DESC) AS UserRank
    FROM 
        Users u
    JOIN 
        Votes v ON u.Id = v.UserId
    WHERE 
        v.VoteTypeId IN (8, 9) -- BountyStart and BountyClose
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        SUM(v.BountyAmount) > 0
),
PostStatistics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.TagNames,
        COALESCE(mph.Comment, 'No recent modifications') AS LastModificationComment,
        COALESCE(mph.CreationDate, 'Never') AS LastModifiedDate,
        COALESCE(mph.UserDisplayName, 'N/A') AS LastModifiedBy,
        tu.DisplayName AS TopUserName,
        tu.TotalBounties
    FROM 
        RankedPosts rp
    LEFT JOIN 
        ModifiedPostHistory mph ON rp.PostId = mph.PostId
    LEFT JOIN 
        TopUsers tu ON tu.UserId = (
            SELECT UserId 
            FROM Votes 
            WHERE PostId = rp.PostId 
            ORDER BY CreationDate DESC 
            LIMIT 1
        )
)
SELECT 
    ps.Title,
    ps.CreationDate,
    ps.TagNames,
    ps.LastModificationComment,
    ps.LastModifiedDate,
    ps.LastModifiedBy,
    COALESCE(ps.TopUserName, 'No Bounties Offered') AS TopUserName,
    COALESCE(ps.TotalBounties, 0) AS TotalBounties
FROM 
    PostStatistics ps
ORDER BY 
    ps.CreationDate DESC
LIMIT 50;
