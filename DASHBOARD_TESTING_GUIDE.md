# Dashboard Canvas - Testing Guide

## ✅ How to Test the Dashboard Feature

### 1. Access the Dashboard Canvas
1. Open http://localhost:5174
2. Click the **"📈 Dashboards"** tab in the header
3. You should see the Dashboard Canvas page

### 2. Test Pre-built Templates

#### Option A: Create from Executive Overview Template
1. Click **"📋 Templates"** button
2. Find **"Executive Overview"** template
3. Click on it
4. Enter a name like "My Executive Dashboard"
5. The dashboard should load with 8 pre-configured widgets

#### Option B: Try Other Templates
- **Clinical Quality Dashboard** - 7 widgets for disease management
- **Financial Performance** - 8 widgets for cost tracking
- **Care Management** - 6 widgets for high-risk patients
- **Blank Canvas** - Start from scratch

### 3. Test Adding a Custom Widget

1. Click **"➕ Add Widget"** button
2. Fill in the form:
   - **Title**: "Total Patients"
   - **Query**: "Show me total patients"
   - **Widget Type**: Chart (Auto-detect)
   - **Width**: 4
   - **Height**: 3
3. Click **"Add Widget"**
4. The widget should appear and load data

### 4. Test Widget Interactions

#### Edit a Widget:
1. Hover over any widget
2. Click the **⚙️ gear icon**
3. Modify the title or query
4. Click **"Update Widget"**

#### Move a Widget:
1. Click and drag the **grip handle** (⋮⋮) at the top of any widget
2. Move it to a new position
3. Release to drop

#### Resize a Widget:
1. Hover over the edge of a widget
2. Drag to resize
3. Release when done

#### Delete a Widget:
1. Click the **❌ X icon** on any widget
2. The widget is removed

### 5. Test Dashboard Persistence

#### Save Dashboard:
1. Make some changes (add/edit/move widgets)
2. Click **"💾 Save"** button
3. You should see "Dashboard saved successfully!"

#### Load Dashboard:
1. Click **"📋 Templates"** to open the drawer
2. Scroll to **"📁 My Dashboards"** section
3. Click on your saved dashboard
4. It should load with all your widgets

#### Delete Dashboard:
1. With a dashboard loaded
2. Click **"🗑️ Delete"** button
3. Confirm deletion
4. Dashboard is removed

### 6. Test Different Widget Types

Try these example queries:

**Metric Cards** (Single Values):
- "Show me total patients"
- "What is the average cost per patient?"
- "How many patients have diabetes?"

**Bar Charts** (Categories):
- "Show me patients by gender"
- "Show me patients by state"

**Donut/Pie Charts** (Compositions):
- "Show me cancer patients by cancer type"
- "Show me patients by age group"

**Grouped Bar Charts** (Multi-dimensional):
- "Show me patients by gender and age group"

**Line Charts** (Time Series):
- "Show me total cost by month"
- "Show me ER visits by month"

**Tables** (Record-level data):
- "Show me top 10 most expensive patients"
- "Show me patients with 3 or more ER visits"

## 🐛 Troubleshooting

### "Network Error" when adding widget:
**FIXED**: This was caused by incorrect API endpoint configuration. The dashboard components were trying to connect directly to `http://localhost:8001` instead of using the Vite proxy. This has been fixed by:
1. Setting `API_BASE = ''` in DashboardCanvas.jsx and DashboardWidget.jsx
2. Ensuring vite.config.js proxy target is `http://app:8000` (internal Docker port)
3. All API requests now go through the Vite dev server proxy at port 5174

If you still see network errors:
1. Check browser console (F12) for specific error messages
2. Ensure backend is running: `docker ps | grep nlsql-app`
3. Test API through proxy: `curl http://localhost:5174/api/dashboards/templates`
4. Restart frontend: `docker-compose restart frontend`

### Templates not loading:
1. Check if API returns data: `curl http://localhost:8001/api/dashboards/templates`
2. Check browser console for JavaScript errors
3. Refresh the page (Ctrl+R or Cmd+R)

### Widget shows "Loading data..." forever:
1. Open browser console
2. Look for query errors
3. The query might be invalid - check the natural language
4. Try a simpler query like "Show me total patients"

### Dashboard not saving:
1. Check that `/app/dashboards` directory exists in container
2. Run: `docker exec nlsql-app ls -la /app/dashboards`
3. Check write permissions

### Drag and drop not working:
1. Make sure you're dragging the grip handle (⋮⋮) not the widget body
2. Refresh the page
3. Check console for JavaScript errors

## 📋 Expected Behavior

### When Everything Works:

1. **Templates**: Click template → Enter name → Dashboard loads with widgets
2. **Add Widget**: Fill form → Click Add → Widget appears and loads data
3. **Edit Widget**: Click gear → Modify → Click Update → Changes apply
4. **Move Widget**: Drag grip handle → Move → Drop → Position updates
5. **Resize Widget**: Drag edge → Resize → Release → Size updates
6. **Save**: Click Save → Success message → Dashboard persists
7. **Load**: Click dashboard → Widgets load with positions → Data populates
8. **Delete**: Click Delete → Confirm → Dashboard removed

### Visual Indicators:

- ✅ Green "Auto-corrected" badge if SQL was fixed
- ⏳ Loading spinner while fetching data
- ❌ Red error box if query fails
- 📊 Chart/metric/table based on data type
- 🔵 Blue Save button (active)
- 🟢 Green Add Widget button
- 🟣 Purple Templates button
- 🔴 Red Delete button

## 🎯 Success Criteria

Your dashboard feature is working if:
- [ ] You can browse and click templates
- [ ] Templates create dashboards with pre-configured widgets
- [ ] You can add custom widgets with natural language queries
- [ ] Widgets load and display data (charts, metrics, or tables)
- [ ] You can drag widgets to reposition them
- [ ] You can resize widgets by dragging edges
- [ ] You can edit widget titles and queries
- [ ] You can delete widgets
- [ ] You can save dashboards
- [ ] Saved dashboards appear in "My Dashboards"
- [ ] You can load saved dashboards
- [ ] Dashboard layouts persist after page refresh
- [ ] You can delete dashboards

## 🚀 Demo Workflow

**Quick 2-Minute Demo:**

1. Click "📈 Dashboards" tab
2. Click "📋 Templates"
3. Click "Executive Overview"
4. Enter name: "Demo Dashboard"
5. Watch as 8 widgets load with real data
6. Drag "Total Patients" widget to top-right
7. Click gear icon on "Cost Trend" widget
8. Change query to "Show me ER visits by month"
9. Click "Update Widget"
10. Click "💾 Save"
11. Refresh page (Cmd+R)
12. Click "📋 Templates" → "My Dashboards" → "Demo Dashboard"
13. Dashboard loads exactly as saved!

**Result**: You now have a live, interactive, drag-and-drop dashboard with real healthcare data!
