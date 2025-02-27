WITH tag_counts AS (
  SELECT 
    unnest(string_to_array(substring(Tags, 2, length(Tags)-2), '><')) AS Tag,
    COUNT(*) AS PostCount
  FROM 
    Posts
  WHERE 
    PostTypeId = 1  -- Only questions
  GROUP BY 
    Tag
),
top_users AS (
  SELECT 
    Id, 
    DisplayName,
    SUM(UpVotes - DownVotes) AS NetVotes,
    COUNT(DISTINCT Id) AS BadgeCount
  FROM 
    Users U
  LEFT JOIN 
    Badges B ON U.Id = B.UserId
  GROUP BY 
    Id, DisplayName
  ORDER BY 
    NetVotes DESC
  LIMIT 10
),
recent_activity AS (
  SELECT 
    P.Id AS PostId,
    P.Title,
    U.DisplayName AS OwnerDisplayName,
    P.CreationDate,
    P.LastActivityDate,
    COALESCE(CAST(P.AcceptedAnswerId AS varchar), 'No Answer') AS AcceptedAnswer,
    C.CommentCount,
    PC.ExcerptPostId IS NOT NULL AS HasExcerpt
  FROM 
    Posts P
  LEFT JOIN 
    Users U ON P.OwnerUserId = U.Id
  LEFT JOIN 
    (SELECT PostId, COUNT(*) AS CommentCount FROM Comments GROUP BY PostId) C ON P.Id = C.PostId
  LEFT JOIN 
    PostLinks PL ON P.Id = PL.PostId
  LEFT JOIN 
    Posts PC ON PL.RelatedPostId = PC.Id
  WHERE 
    P.CreationDate > NOW() - INTERVAL '1 month'
)
SELECT 
  tg.Tag,
  tc.PostCount,
  ua.DisplayName AS TopUser,
  ua.NetVotes,
  ar.PostId,
  ar.Title,
  ar.OwnerDisplayName,
  ar.CreationDate,
  ar.LastActivityDate,
  ar.AcceptedAnswer,
  ar.CommentCount,
  ar.HasExcerpt
FROM 
  tag_counts tc
JOIN 
  top_users ua ON ua.BadgeCount > 0
JOIN 
  recent_activity ar ON ar.Title ILIKE '%' || tc.Tag || '%'
ORDER BY 
  tc.PostCount DESC, ua.NetVotes DESC
LIMIT 5;
