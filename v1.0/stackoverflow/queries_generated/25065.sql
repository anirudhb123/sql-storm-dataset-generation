WITH TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.UpVotes > 0 THEN p.UpVotes ELSE 0 END) AS TotalUpVotes,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS Rank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
RecentPostEdits AS (
    SELECT 
        ph.PostId,
        ph.UserId AS EditorUserId,
        ph.CreationDate AS EditDate,
        ph.PostHistoryTypeId,
        ph.Comment,
        CASE 
            WHEN ph.PostHistoryTypeId IN (4, 5, 6) THEN 'Edited'
            WHEN ph.PostHistoryTypeId IN (10, 11) THEN 'Closure Action'
            ELSE 'Other Actions'
        END AS ActionType
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= NOW() - INTERVAL '30 days'
)
SELECT 
    tu.DisplayName AS Editor,
    tu.Reputation,
    COUNT(DISTINCT rpe.EditDate) AS EditCount,
    SUM(CASE WHEN rpe.ActionType = 'Edited' THEN 1 ELSE 0 END) AS TotalEdits,
    SUM(CASE WHEN rpe.ActionType = 'Closure Action' THEN 1 ELSE 0 END) AS TotalClosures,
    AVG(tu.TotalUpVotes * 1.0 / NULLIF(tu.PostCount, 0)) AS AvgVotesPerPost,
    STRING_AGG(DISTINCT tg.TagName, ', ') AS PopularTags
FROM 
    TopUsers tu
JOIN 
    RecentPostEdits rpe ON tu.UserId = rpe.EditorUserId
JOIN 
    Posts p ON rpe.PostId = p.Id
LEFT JOIN 
    STRING_TO_ARRAY(p.Tags, ',') AS tag_array ON TRUE
LEFT JOIN 
    Tags tg ON tg.TagName = tag_array
WHERE 
    tu.Rank <= 10
GROUP BY 
    tu.DisplayName, tu.Reputation
ORDER BY 
    EditCount DESC, tu.Reputation DESC;
