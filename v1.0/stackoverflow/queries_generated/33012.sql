WITH RECURSIVE UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.Score > 0 THEN p.Score ELSE 0 END) AS TotalPositiveScore,
        SUM(CASE WHEN p.Score < 0 THEN p.Score ELSE 0 END) AS TotalNegativeScore,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY SUM(CASE WHEN p.Score > 0 THEN p.Score ELSE 0 END) DESC) AS Rank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        TotalPositiveScore,
        TotalNegativeScore
    FROM 
        UserPostStats
    WHERE 
        Rank <= 10
)
SELECT 
    tu.DisplayName,
    tu.PostCount,
    tu.TotalPositiveScore,
    tu.TotalNegativeScore,
    COALESCE(b.Name, 'No Badge') AS BadgeName,
    CASE 
        WHEN tu.TotalPositiveScore + ABS(tu.TotalNegativeScore) = 0 THEN 0
        ELSE ROUND((tu.TotalPositiveScore::numeric / (tu.TotalPositiveScore + ABS(tu.TotalNegativeScore))) * 100, 2)
    END AS PositiveScorePercentage,
    STRING_AGG(DISTINCT t.TagName, ', ') AS AssociatedTags
FROM 
    TopUsers tu
LEFT JOIN 
    Badges b ON tu.UserId = b.UserId AND b.Class = 1 -- Gold Badge
LEFT JOIN 
    Posts p ON tu.UserId = p.OwnerUserId
LEFT JOIN 
    Tags t ON p.Tags LIKE '%' || t.TagName || '%' 
GROUP BY 
    tu.UserId, tu.DisplayName, tu.PostCount, tu.TotalPositiveScore, tu.TotalNegativeScore, b.Name
ORDER BY 
    tu.TotalPositiveScore DESC, tu.PostCount DESC
LIMIT 20;

WITH PostVoteCounts AS (
    SELECT 
        p.Id AS PostId,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
), 
MostVotedPosts AS (
    SELECT 
        p.Title,
        pvc.VoteCount,
        pvc.UpVotes,
        pvc.DownVotes,
        ROW_NUMBER() OVER (ORDER BY pvc.VoteCount DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        PostVoteCounts pvc ON p.Id = pvc.PostId
    WHERE 
        p.PostTypeId = 1 -- Questions only
)
SELECT 
    Title,
    VoteCount,
    UpVotes,
    DownVotes,
    CASE 
        WHEN DownVotes = 0 THEN 'No Down Votes'
        ELSE ROUND((UpVotes::numeric / (UpVotes + DownVotes)) * 100, 2) || '%' 
    END AS UpvotePercentage
FROM 
    MostVotedPosts
WHERE 
    PostRank <= 5;

-- Final benchmarking of repeated user post edits
SELECT 
    ph.UserId,
    u.DisplayName,
    ph.PostId,
    COUNT(*) AS EditCount,
    MIN(ph.CreationDate) AS FirstEditDate,
    MAX(ph.CreationDate) AS LastEditDate,
    COUNT(DISTINCT ph.PostHistoryTypeId) AS EditTypeCount,
    STRING_AGG(DISTINCT CASE WHEN ph.PostHistoryTypeId IN (4, 5) THEN 'Edited' ELSE 'Other' END, ', ') AS EditTypes
FROM 
    PostHistory ph
JOIN 
    Users u ON ph.UserId = u.Id
WHERE 
    ph.PostHistoryTypeId IN (4, 5) -- Title and Body Edits
GROUP BY 
    ph.UserId, u.DisplayName, ph.PostId
HAVING 
    COUNT(*) > 1
ORDER BY 
    EditCount DESC;
