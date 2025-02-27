WITH TagCounts AS (
    SELECT 
        string_agg(DISTINCT t.TagName, ', ') AS AllTags,
        COUNT(*) AS TagCount
    FROM 
        Posts p
    JOIN 
        Tags t ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id
),
TopUsers AS (
    SELECT 
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Users u
    JOIN 
        Posts p ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        u.Id
    ORDER BY 
        TotalViews DESC
    LIMIT 10
),
RecentEdits AS (
    SELECT 
        ph.UserDisplayName,
        ph.CreationDate,
        p.Title,
        p.Id AS PostId,
        T.Name AS PostHistoryType
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    JOIN 
        PostHistoryTypes T ON ph.PostHistoryTypeId = T.Id
    WHERE 
        ph.CreationDate >= NOW() - INTERVAL '30 days' 
    ORDER BY 
        ph.CreationDate DESC
    LIMIT 20
)
SELECT 
    tu.DisplayName AS TopUser,
    tu.Reputation,
    tu.QuestionCount,
    tc.AllTags,
    tc.TagCount,
    re.UserDisplayName AS Editor,
    re.CreationDate AS EditDate,
    re.Title AS EditedPostTitle,
    re.PostId
FROM 
    TopUsers tu
JOIN 
    TagCounts tc ON true -- Cartesian join to include all tags
JOIN 
    RecentEdits re ON true -- Cartesian join to include all recent edits
ORDER BY 
    tu.Reputation DESC, 
    tc.TagCount DESC, 
    re.EditDate DESC;
