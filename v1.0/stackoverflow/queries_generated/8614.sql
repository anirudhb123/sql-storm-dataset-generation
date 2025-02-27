WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND p.Score > 0
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(pt.RecordId) AS RelatedPostsCount
    FROM 
        Tags t
    JOIN 
        Posts p ON t.Id IN (SELECT UNNEST(string_to_array(p.Tags, '><'))::int) 
    LEFT JOIN 
        (SELECT 
            PostId AS RecordId 
         FROM 
            PostLinks 
         WHERE 
            LinkTypeId = 3) pt ON p.Id = pt.RecordId
    GROUP BY 
        t.TagName
),
TopUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes,
        RANK() OVER (ORDER BY SUM(u.Reputation) DESC) AS UserRank
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostHistoryAnalysis AS (
    SELECT 
        p.Id AS PostId,
        ph.UserId,
        ph.CreationDate AS EditDate,
        p.Title,
        ph.Comment,
        ph.PostHistoryTypeId
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12) /* Closed, Reopened, Deleted */
)
SELECT 
    rp.Title,
    rp.OwnerDisplayName,
    rp.CreationDate,
    rp.ViewCount,
    pt.TagName,
    tu.DisplayName AS TopUser,
    tu.TotalUpVotes,
    tu.TotalDownVotes,
    ph.EditDate,
    ph.Comment
FROM 
    RankedPosts rp
LEFT JOIN 
    PopularTags pt ON rp.Id IN (SELECT PostId FROM PostLinks WHERE RelatedPostId = rp.Id)
LEFT JOIN 
    TopUsers tu ON tu.UserRank = 1
LEFT JOIN 
    PostHistoryAnalysis ph ON ph.PostId = rp.Id
WHERE 
    rp.PostRank <= 5 /* Get top 5 posts by each user */
ORDER BY 
    rp.Score DESC, rp.CreationDate DESC;
