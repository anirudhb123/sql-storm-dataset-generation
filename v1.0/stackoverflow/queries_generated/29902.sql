WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.Tags,
        COUNT(DISTINCT c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY ph.CreationDate DESC) AS LatestHistory
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.PostTypeId IN (1, 2) -- Only questions and answers
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.Tags
),
AggregatedTags AS (
    SELECT 
        unnest(string_to_array(Tags, ',')) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 -- Only questions
    GROUP BY 
        unnest(string_to_array(Tags, ','))
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes,
        COUNT(DISTINCT p.Id) AS QuestionsAnswered
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.PostTypeId = 2 -- Only answers
    GROUP BY 
        u.Id, u.DisplayName
    ORDER BY 
        TotalUpVotes DESC
    LIMIT 10
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.Tags,
    rp.CommentCount,
    at.TagName,
    tu.DisplayName AS TopUser,
    tu.TotalUpVotes,
    tu.TotalDownVotes
FROM 
    RankedPosts rp
LEFT JOIN 
    AggregatedTags at ON rp.Tags ILIKE '%' || at.TagName || '%'
LEFT JOIN 
    TopUsers tu ON rp.PostId IN (SELECT p.Id FROM Posts p WHERE p.AcceptedAnswerId = rp.PostId)
WHERE 
    rp.LatestHistory = 1
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC
LIMIT 50;
