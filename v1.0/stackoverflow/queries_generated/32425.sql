WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE 
            WHEN v.VoteTypeId = 2 THEN 1 
            ELSE 0 
        END) AS UpVotes,
        SUM(CASE 
            WHEN v.VoteTypeId = 3 THEN 1 
            ELSE 0 
        END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(pt.PostId) AS TagCount
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    LEFT JOIN 
        PostLinks pl ON p.Id = pl.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '2 years'
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(pt.PostId) > 5
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 END) AS ReopenCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 12 THEN 1 END) AS DeleteCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)

SELECT 
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.CommentCount,
    rp.UpVotes,
    rp.DownVotes,
    tu.DisplayName AS TopUser,
    pt.TagName,
    phs.CloseCount,
    phs.ReopenCount,
    phs.DeleteCount
FROM 
    RankedPosts rp
JOIN 
    TopUsers tu ON rp.Rank <= 5
JOIN 
    PopularTags pt ON rp.PostId IN (SELECT PostId FROM Posts WHERE Tags LIKE CONCAT('%', pt.TagName, '%')) 
LEFT JOIN 
    PostHistorySummary phs ON rp.PostId = phs.PostId
WHERE 
    rp.ViewCount > 100
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC;
