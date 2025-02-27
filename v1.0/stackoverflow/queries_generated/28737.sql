WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        RANK() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS TagRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Questions only
        AND p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'  -- Last year
),
PopularTags AS (
    SELECT 
        unnest(string_to_array(Tags, ',')) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        RankedPosts
    WHERE 
        TagRank = 1
    GROUP BY 
        TagName
    HAVING 
        COUNT(*) > 5  -- Only include tags that have more than 5 questions
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT p.Id) AS AnswerCount
    FROM 
        Users u
    JOIN 
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.PostTypeId = 2  -- Answers only
        AND p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        u.Id, u.DisplayName
),
RecentPostHistory AS (
    SELECT 
        ph.PostId,
        ph.UserDisplayName,
        ph.CreationDate,
        ph.Comment,
        pt.Name AS PostHistoryTypeName
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
    WHERE 
        ph.CreationDate >= CURRENT_DATE - INTERVAL '1 month'  -- Last month
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Tags,
    pt.PostHistoryTypeName,
    pgh.UserDisplayName AS EditedBy,
    pgh.CreationDate AS EditDate,
    tu.DisplayName AS TopUser,
    tu.UpVotes,
    tu.DownVotes,
    tu.AnswerCount
FROM 
    RankedPosts rp
JOIN 
    RecentPostHistory pgh ON rp.PostId = pgh.PostId
JOIN 
    PopularTags pt ON pt.TagName = ANY(string_to_array(rp.Tags, ','))
JOIN 
    TopUsers tu ON tu.UserId IN (SELECT DISTINCT OwnerUserId FROM Posts WHERE Id = rp.PostId)
WHERE 
    rp.TagRank = 1
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC
LIMIT 100;  -- Limit to 100 results for benchmarking
